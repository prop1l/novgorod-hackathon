import 'package:flutter/material.dart';

import '../main.dart';
import '../models/achievement.dart';
import '../theme.dart';
import '../widgets/achievement_badge.dart';

const _months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final unlocked = state.unlockedAchievements;
    // Сначала полученные, потом — по близости к получению.
    final items = [for (final a in achievements) (a, state.progressOf(a))]
      ..sort((x, y) {
        final ux = unlocked.containsKey(x.$1.id), uy = unlocked.containsKey(y.$1.id);
        if (ux != uy) return ux ? -1 : 1;
        return y.$2.fraction.compareTo(x.$2.fraction);
      });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('Достижения', style: AppText.screenTitle),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Получено ${unlocked.length} из ${achievements.length}',
              style: AppText.small.copyWith(color: AppColors.text),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _Bar(value: unlocked.length / achievements.length),
          ),
          const SizedBox(height: 20),
          for (final (a, p) in items) ...[
            _AchievementCard(achievement: a, progress: p, unlockedAt: unlocked[a.id]),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, required this.progress, this.unlockedAt});

  final Achievement achievement;
  final AchievementProgress progress;
  final DateTime? unlockedAt;

  @override
  Widget build(BuildContext context) {
    final at = unlockedAt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          AchievementBadge(achievement: achievement, unlocked: at != null, size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title, style: AppText.h3),
                const SizedBox(height: 2),
                Text(achievement.description, style: AppText.small),
                const SizedBox(height: 10),
                if (at != null)
                  Row(children: [
                    const Icon(Icons.check_circle, size: 16, color: AppColors.visited),
                    const SizedBox(width: 6),
                    Text('Получено ${at.day} ${_months[at.month - 1]}',
                        style: AppText.caption.copyWith(color: AppColors.visited)),
                  ])
                else
                  Row(children: [
                    Expanded(child: _Bar(value: progress.fraction)),
                    const SizedBox(width: 10),
                    Text('${progress.done} / ${progress.target}', style: AppText.caption),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 6,
        color: AppColors.accent,
        backgroundColor: AppColors.accentSoft,
      ),
    );
  }
}
