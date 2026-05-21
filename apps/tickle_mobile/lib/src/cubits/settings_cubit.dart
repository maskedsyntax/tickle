import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Settings State
class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final String hapticLevel; // 'off', 'light', 'medium', 'heavy'
  final bool isLoaded;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.hapticLevel = 'medium',
    this.isLoaded = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? hapticLevel,
    bool? isLoaded,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      hapticLevel: hapticLevel ?? this.hapticLevel,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [themeMode, hapticLevel, isLoaded];
}

// Cubit
class SettingsCubit extends Cubit<SettingsState> {
  static const String _themeKey = 'pref_theme_mode';
  static const String _hapticKey = 'pref_haptic_level';

  SettingsCubit() : super(const SettingsState());

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isClosed) return;
      
      // Load Theme
      final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
      final themeMode = ThemeMode.values[themeIndex];

      // Load Haptics
      final hapticLevel = prefs.getString(_hapticKey) ?? 'medium';

      emit(SettingsState(
        themeMode: themeMode,
        hapticLevel: hapticLevel,
        isLoaded: true,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(isLoaded: true));
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    try {
      emit(state.copyWith(themeMode: mode));
      final prefs = await SharedPreferences.getInstance();
      if (isClosed) return;
      await prefs.setInt(_themeKey, mode.index);
    } catch (_) {}
  }

  Future<void> updateHapticLevel(String level) async {
    if (!['off', 'light', 'medium', 'heavy'].contains(level)) return;
    try {
      emit(state.copyWith(hapticLevel: level));
      final prefs = await SharedPreferences.getInstance();
      if (isClosed) return;
      await prefs.setString(_hapticKey, level);
    } catch (_) {}
  }
}
