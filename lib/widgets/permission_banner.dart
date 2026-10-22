import 'package:flutter/material.dart';

import '../main.dart';
import '../services/location_service.dart';

/// Понятное объяснение, если геолокация недоступна — вместо краша или пустой карты.
class PermissionBanner extends StatelessWidget {
  const PermissionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.demoRunning || !state.guideEnabled) return const SizedBox.shrink();

    final (String text, String action, Future<void> Function() onTap)? info = switch (state.access) {
      LocationAccess.serviceOff => (
          'Геолокация на телефоне выключена — гид не знает, где вы.',
          'Включить',
          state.location.openSettings,
        ),
      LocationAccess.denied => (
          'Разрешите доступ к геопозиции, чтобы гид подсказывал места рядом.',
          'Разрешить',
          state.requestAccess,
        ),
      LocationAccess.deniedForever => (
          'Доступ к геопозиции запрещён. Его можно включить в настройках приложения.',
          'Настройки',
          state.location.openSettings,
        ),
      _ => null,
    };
    if (info == null) return const SizedBox.shrink();
    final (text, action, onTap) = info;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.location_off),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
            TextButton(onPressed: onTap, child: Text(action)),
          ],
        ),
      ),
    );
  }
}
