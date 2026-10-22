import 'package:flutter/material.dart';

import '../main.dart';
import '../services/location_service.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scale = '×${state.radiusScale.toStringAsFixed(2)}';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.paddingOf(context).bottom + 24),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 16),
              child: Text('Настройки', style: AppText.screenTitle),
            ),
            _Card(children: [
              _Row(
                icon: Icons.notifications_active_outlined,
                title: 'Гид',
                subtitle: 'Уведомлять о местах рядом, даже когда приложение свёрнуто',
                trailing: Switch(value: state.guideEnabled, onChanged: state.setGuideEnabled),
                onTap: () => state.setGuideEnabled(!state.guideEnabled),
              ),
              _Row(
                icon: Icons.radar,
                title: 'Радиус срабатывания',
                bottom: Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          overlayShape: SliderComponentShape.noOverlay,
                          trackHeight: 5,
                        ),
                        child: Slider(
                          value: state.radiusScale,
                          min: 0.5,
                          max: 3,
                          divisions: 10,
                          label: scale,
                          onChanged: state.setRadiusScale,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(scale, style: AppText.small.copyWith(color: AppColors.text)),
                  ],
                ),
              ),
              _Row(
                icon: Icons.location_on_outlined,
                title: 'Доступ к геопозиции',
                subtitle: _accessText(state.access),
                trailing: const Icon(Icons.open_in_new, color: AppColors.textSecondary),
                onTap: state.location.openSettings,
              ),
              _Row(
                icon: Icons.restart_alt,
                title: 'Сбросить посещённые места',
                onTap: () => _confirmReset(context),
              ),
            ]),
            const SizedBox(height: 16),
            _Card(children: [
              _Row(
                icon: state.demoRunning ? Icons.stop_circle_outlined : Icons.directions_walk,
                title: state.demoRunning ? 'Остановить демо-прогулку' : 'Демо-прогулка',
                subtitle: 'Позиция сама идёт от Кокуя до Ильиной улицы, приходят настоящие уведомления',
                onTap: state.demoRunning ? state.stopDemo : state.startDemo,
              ),
            ]),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Если уведомления не приходят на Xiaomi, Huawei, Honor или Samsung — '
                'разрешите приложению работать в фоне: Настройки › Приложения › '
                '«Здесь было…» › Батарея › «Без ограничений».\n\n'
                'Карта: © MapTiler © OpenStreetMap contributors.',
                style: AppText.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final state = AppScope.read(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: const Text('Сбросить прогресс?', style: AppText.h3),
        content: const Text('Отметки «посещено» и история уведомлений будут удалены.', style: AppText.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (ok ?? false) state.resetProgress();
  }

  static String _accessText(LocationAccess access) => switch (access) {
        LocationAccess.always => 'Разрешён всегда',
        LocationAccess.whileInUse => 'При использовании — фон работает через «Гид активен»',
        LocationAccess.denied => 'Не разрешён',
        LocationAccess.deniedForever => 'Запрещён — включите в настройках',
        LocationAccess.serviceOff => 'Геолокация на телефоне выключена',
        LocationAccess.unknown => 'Проверяем…',
      };
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 60),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, this.subtitle, this.trailing, this.bottom, this.onTap});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? bottom;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, color: AppColors.accent, size: 26),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.body.copyWith(fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppText.caption.copyWith(fontWeight: FontWeight.w400)),
                  ],
                  if (bottom != null) ...[const SizedBox(height: 8), bottom!],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
