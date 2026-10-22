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
    final distance = state.distanceTo(place);
    final visited = state.visited.contains(place.id);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(height: 340 + top, child: ThenNowSlider(place: place)),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 32 + MediaQuery.paddingOf(context).bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: AppText.h2),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(icon: place.category.icon, label: place.category.label),
                        _Chip(icon: Icons.history, label: place.era),
                        if (distance != null) _Chip(icon: Icons.near_me_outlined, label: formatDistance(distance)),
                        if (visited) const _Chip(icon: Icons.check_circle_outline, label: 'Посещено', visited: true),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(place.short, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                    _Section(icon: Icons.foundation, title: 'Как появилось', text: place.history),
                    _Section(icon: Icons.auto_stories_outlined, title: 'Что тут было', text: place.whatHappened),
                    if (place.activities.isNotEmpty)
                      _Section(icon: Icons.groups_outlined, title: 'Что тут делали', text: place.activities),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _openRoute(context),
                        icon: const Icon(Icons.directions_walk),
                        label: const Text('Маршрут'),
                      ),
                    ),
                    if (place.photoCredit.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Фото: ${place.photoCredit}', style: AppText.caption.copyWith(fontWeight: FontWeight.w400)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            top: top + 12,
            child: Material(
              color: AppColors.card,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).maybePop(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.arrow_back, color: AppColors.text),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, this.visited = false});

  final IconData icon;
  final String label;
  final bool visited;

  @override
  Widget build(BuildContext context) {
    final color = visited ? AppColors.visited : AppColors.accent;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
      decoration: BoxDecoration(
        color: visited ? AppColors.card : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(16),
        border: visited ? Border.all(color: AppColors.visited) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppText.caption.copyWith(color: color)),
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
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 22, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(title, style: AppText.h3),
          ]),
          const SizedBox(height: 6),
          Text(text, style: AppText.body.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
