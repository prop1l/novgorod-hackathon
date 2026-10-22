import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/place_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load();
  final launchPlaceId = await state.notifications.init();
  state.notifications.onOpenPlace = openPlace;
  runApp(NovgorodApp(state: state, launchPlaceId: launchPlaceId));
}

void openPlace(String placeId) {
  final nav = navigatorKey.currentState;
  final place = AppScope.read(nav!.context).placeById(placeId);
  if (place == null) return;
  nav.push(MaterialPageRoute<void>(builder: (_) => PlaceScreen(place: place)));
}

/// Даёт виджетам доступ к [AppState] и перестраивает их при его изменении.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

class NovgorodApp extends StatelessWidget {
  const NovgorodApp({super.key, required this.state, this.launchPlaceId});

  final AppState state;
  final String? launchPlaceId;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Здесь было…',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: buildTheme(),
        home: state.storage.onboardingDone
            ? HomeScreen(launchPlaceId: launchPlaceId)
            : const OnboardingScreen(),
      ),
    );
  }
}
