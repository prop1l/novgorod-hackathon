import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/app_nav_bar.dart';
import 'map_screen.dart';
import 'places_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.launchPlaceId});

  /// Место, на котором открыть приложение после тапа по уведомлению.
  final String? launchPlaceId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.read(context).refreshAccess();
      final id = widget.launchPlaceId;
      if (id != null) openPlace(id);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Пользователь мог выдать разрешение в системных настройках.
    if (state == AppLifecycleState.resumed) AppScope.read(context).refreshAccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [MapScreen(), PlacesListScreen(), SettingsScreen()],
      ),
      extendBody: true,
      bottomNavigationBar: AppNavBar(
        selected: _tab,
        onSelect: (i) => setState(() => _tab = i),
      ),
    );
  }
}
