import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final bool isPanelOpen;
  const SettingsState({this.isPanelOpen = false});
  SettingsState copyWith({bool? isPanelOpen}) =>
      SettingsState(isPanelOpen: isPanelOpen ?? this.isPanelOpen);
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void openPanel() => state = state.copyWith(isPanelOpen: true);
  void closePanel() => state = state.copyWith(isPanelOpen: false);
  void togglePanel() => state = state.copyWith(isPanelOpen: !state.isPanelOpen);
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
