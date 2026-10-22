import 'package:flutter/material.dart';

import '../main.dart';
import '../services/location_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Гид'),
            subtitle: const Text('Уведомлять о местах рядом, даже когда приложение свёрнуто'),
            value: state.guideEnabled,
            onChanged: state.setGuideEnabled,
          ),
          ListTile(
            leading: const Icon(Icons.radar),
            title: const Text('Радиус срабатывания'),
            subtitle: Slider(
              value: state.radiusScale,
              min: 0.5,
              max: 3,
              divisions: 10,
              label: '×${state.radiusScale.toStringAsFixed(2)}',
              onChanged: state.setRadiusScale,
            ),
            trailing: Text('×${state.radiusScale.toStringAsFixed(2)}'),
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Доступ к геопозиции'),
            subtitle: Text(_accessText(state.access)),
            trailing: const Icon(Icons.open_in_new),
            onTap: state.location.openSettings,
          ),
          const Divider(),
          ListTile(
            leading: Icon(state.demoRunning ? Icons.stop_circle_outlined : Icons.directions_walk),
            title: Text(state.demoRunning ? 'Остановить демо-прогулку' : 'Демо-прогулка'),
            subtitle: const Text(
                'Виртуальная прогулка от Кокуя до Ильиной улицы: позиция двигается сама, приходят настоящие уведомления'),
            onTap: state.demoRunning ? state.stopDemo : state.startDemo,
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Сбросить посещённые места'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Сбросить прогресс?'),
                  content: const Text('Отметки «посещено» и история уведомлений будут удалены.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сбросить')),
                  ],
                ),
              );
              if (ok ?? false) state.resetProgress();
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Если уведомления перестают приходить на Xiaomi, Huawei, Honor или Samsung — '
              'разрешите приложению работать в фоне: Настройки → Приложения → '
              'Новгород сквозь время → Батарея → «Без ограничений».\n\n'
              'Карта: © MapTiler © OpenStreetMap contributors.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  static String _accessText(LocationAccess access) => switch (access) {
        LocationAccess.always => 'Разрешён всегда',
        LocationAccess.whileInUse => 'Разрешён при использовании (фон работает через «Гид активен»)',
        LocationAccess.denied => 'Не разрешён',
        LocationAccess.deniedForever => 'Запрещён — включите в настройках',
        LocationAccess.serviceOff => 'Геолокация на телефоне выключена',
        LocationAccess.unknown => 'Проверяем…',
      };
}
