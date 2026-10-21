import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Çelësi ku ruhet zgjedhja e pamjes.
const String kThemeModeKey = 'shendet_theme_mode';

/// Kontrollon pamjen (E ndritshme / E errët) dhe e ruan zgjedhjen,
/// që të mbetet e njëjta edhe pas rihapjes së aplikacionit.
///
/// Parazgjedhja është GJITHMONË e ndritshme — pavarësisht nëse sistemi
/// operativ është në modalitet të errët. Përdoruesi e zgjedh të errëtën
/// vetëm me veprim të vetëdijshëm.
class ThemeModeController extends Notifier<ThemeMode> {
  ThemeModeController([this._initial = ThemeMode.light]);

  final ThemeMode _initial;

  @override
  ThemeMode build() => _initial;

  Future<void> setMode(ThemeMode mode) async {
    // Vetëm dy pamje mbështeten; çdo vlerë tjetër bie te e ndritshmja.
    final next = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    if (next == state) return;
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kThemeModeKey, next.name);
    } catch (_) {
      // Ruajtja dështon vetëm në raste ekstreme; pamja ndryshon gjithsesi.
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Lexohet para `runApp` që të mos ketë "flakërim" të pamjes së gabuar.
///
/// Vlera e vjetër "system" (ose çdo vlerë e panjohur) trajtohet si e ndritshme
/// dhe normalizohet në ruajtje, që të mos kthehet më kurrë dark pa dashje.
Future<ThemeMode> loadStoredThemeMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(kThemeModeKey);
    final mode = stored == ThemeMode.dark.name
        ? ThemeMode.dark
        : ThemeMode.light;
    if (stored != mode.name) {
      await prefs.setString(kThemeModeKey, mode.name);
    }
    return mode;
  } catch (_) {
    return ThemeMode.light;
  }
}
