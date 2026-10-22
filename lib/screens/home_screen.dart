import 'package:flutter/material.dart';

import '../main.dart';
import '../state/app_state.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/app_nav_bar.dart';
import 'achievements_screen.dart';
import 'map_screen.dart';
import 'places_list_screen.dart';
import 'settings_screen.dart';

/// Текущая вкладка главного экрана — чтобы другие экраны могли переключить её (например, на карту).
final homeTab = ValueNotifier<int>(0);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.launchPlaceId});

  /// Место, на котором открыть приложение после тапа по уведомлению.
  final String? launchPlaceId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AppState? _state;
  bool _showingUnlock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _state = AppScope.read(context)..addListener(_showNextUnlock);
      _state!.refreshAccess();
      final id = widget.launchPlaceId;
      if (id != null) openPlace(id);
    });
  }

  @override
  void dispose() {
    _state?.removeListener(_showNextUnlock);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Показывает полученные достижения по одному, поверх любого открытого экрана.
  Future<void> _showNextUnlock() async {
    final state = _state;
    if (_showingUnlock || state == null || !state.hasPendingUnlock) return;
    final overlay = navigatorKey.currentState?.overlay?.context;
    final a = state.takeUnlock();
    if (overlay == null || a == null) return;
    _showingUnlock = true;
    await showAchievementUnlocked(
      overlay,
      a,
      onOpenAll: () => navigatorKey.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
      ),
    );
    _showingUnlock = false;
    if (mounted) _showNextUnlock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Пользователь мог выдать разрешение в системных настройках.
    if (state == AppLifecycleState.resumed) AppScope.read(context).refreshAccess();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: homeTab,
      builder: (context, tab, _) => Scaffold(
        body: IndexedStack(
          index: tab,
          children: const [MapScreen(), PlacesListScreen(), SettingsScreen()],
        ),
        extendBody: true,
        bottomNavigationBar: AppNavBar(selected: tab, onSelect: (i) => homeTab.value = i),
      ),
    );
  }
}
