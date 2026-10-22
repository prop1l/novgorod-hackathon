import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../models/place.dart';
import '../services/geo.dart';
import '../theme.dart';
import '../widgets/then_now_slider.dart';

class PlaceScreen extends StatelessWidget {
  const PlaceScreen({super.key, required this.place});

  final Place place;

  Future<void> _openRoute(BuildContext context) async {
    // Яндекс Карты: пешеходный маршрут от текущего места; откроет приложение, если оно есть.
    final uri = Uri.parse(
        'https://yandex.ru/maps/?rtext=~${place.lat},${place.lon}&rtt=pd');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Не удалось открыть карты')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final distance = state.distanceTo(place);
    final visited = state.visited.contains(place.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(bottom: false, child: ThenNowSlider(place: place)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(children: [
              Text(place.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(avatar: Icon(place.category.icon, size: 18), label: Text(place.category.label)),
                  Chip(avatar: const Icon(Icons.history, size: 18), label: Text(place.era)),
                  if (distance != null)
                    Chip(avatar: const Icon(Icons.near_me, size: 18), label: Text(formatDistance(distance))),
                  if (visited)
                    const Chip(
                      avatar: Icon(Icons.check_circle, size: 18, color: AppColors.visited),
                      label: Text('Посещено'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(place.short, style: theme.textTheme.titleMedium),
              _Section(icon: Icons.foundation, title: 'Как появилось', text: place.history),
              _Section(icon: Icons.auto_stories, title: 'Что тут было', text: place.whatHappened),
              if (place.activities.isNotEmpty)
                _Section(icon: Icons.groups, title: 'Что тут делали', text: place.activities),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _openRoute(context),
                icon: const Icon(Icons.directions_walk),
                label: const Text('Маршрут'),
              ),
              if (place.photoCredit.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Фото: ${place.photoCredit}', style: theme.textTheme.bodySmall),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: AppColors.cinnabar),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleMedium),
          ]),
          const SizedBox(height: 6),
          Text(text, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
