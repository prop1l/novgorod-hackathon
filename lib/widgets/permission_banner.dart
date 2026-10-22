import 'package:flutter/material.dart';

import '../main.dart';
import '../services/location_service.dart';
import '../theme.dart';

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

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(color: AppColors.bgDark, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.location_off_outlined, color: AppColors.onDark),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppText.small.copyWith(color: AppColors.onDark))),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
            child: Text(action),
          ),
        ],
      ),
    );
  }
}
