import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_recommender/theme/trip_pick_theme.dart';

void main() {
  test('light and dark palettes keep readable body-text contrast', () {
    for (final palette in [TripPickPalette.light, TripPickPalette.dark]) {
      expect(
        _contrastRatio(palette.text, palette.canvas),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(palette.text, palette.raisedSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(palette.mutedText, palette.raisedSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(palette.heroText, palette.heroSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(palette.onSelection, palette.selection),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('vivid palette retains the requested controlled accent colors', () {
    expect(TripPickPalette.light.canvas, const Color(0xFFFFF8EC));
    expect(TripPickPalette.light.primary, const Color(0xFF087F6A));
    expect(TripPickPalette.light.primaryStrong, const Color(0xFF075E54));
    expect(TripPickPalette.light.accent, const Color(0xFFE76F51));
    expect(TripPickPalette.light.sun, const Color(0xFFF2B84B));

    expect(TripPickPalette.dark.canvas, const Color(0xFF071712));
    expect(TripPickPalette.dark.raisedSurface, const Color(0xFF173129));
    expect(TripPickPalette.dark.primary, const Color(0xFF4FD1B5));
    expect(TripPickPalette.dark.accent, const Color(0xFFFF8B68));
    expect(TripPickPalette.dark.sun, const Color(0xFFF2C45E));
  });

  test('theme builders expose their semantic palettes', () {
    expect(
      TripPickTheme.light.extension<TripPickPalette>(),
      TripPickPalette.light,
    );
    expect(
      TripPickTheme.dark.extension<TripPickPalette>(),
      TripPickPalette.dark,
    );
    expect(TripPickTheme.light.brightness, Brightness.light);
    expect(TripPickTheme.dark.brightness, Brightness.dark);
  });
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = foreground == lighter ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
