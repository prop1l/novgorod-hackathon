import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../theme.dart';

/// Круглый значок достижения: синий, если получено, серый контур — если ещё нет.
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({super.key, required this.achievement, required this.unlocked, this.size = 64});

  final Achievement achievement;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: unlocked ? AppColors.accent : AppColors.bgLight,
        border: unlocked ? null : Border.all(color: AppColors.border, width: 2),
      ),
      child: Icon(
        achievement.icon,
        size: size * 0.5,
        color: unlocked ? Colors.white : AppColors.textSecondary.withValues(alpha: 0.6),
      ),
    );
  }
}

/// Карточка «Новое достижение!» поверх экрана.
Future<void> showAchievementUnlocked(BuildContext context, Achievement a, {VoidCallback? onOpenAll}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bgDark,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AchievementBadge(achievement: a, unlocked: true, size: 96),
            const SizedBox(height: 20),
            Text('Новое достижение!', style: AppText.caption.copyWith(color: AppColors.accentSoft, fontSize: 14)),
            const SizedBox(height: 6),
            Text(a.title, textAlign: TextAlign.center, style: AppText.h2.copyWith(color: AppColors.onDark)),
            const SizedBox(height: 8),
            Text(a.description, textAlign: TextAlign.center, style: AppText.body.copyWith(color: AppColors.onDark)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Отлично')),
            ),
            if (onOpenAll != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onOpenAll();
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.onDark),
                child: const Text('Все достижения'),
              ),
          ],
        ),
      ),
    ),
  );
}
