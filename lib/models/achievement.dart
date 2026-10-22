import 'package:flutter/material.dart';

import 'place.dart';

/// Достижение за посещённые места: конкретный набор мест, места категории или любые места.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.placeIds,
    this.category,
    this.count,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;

  /// Нужно посетить все эти места.
  final Set<String>? placeIds;

  /// Нужно посетить [count] мест этой категории (или любых, если категория не задана).
  final PlaceCategory? category;

  /// Сколько мест нужно; `null` вместе с пустыми условиями — все места каталога.
  final int? count;

  AchievementProgress progress(Set<String> visited, List<Place> places) {
    final ids = placeIds;
    if (ids != null) {
      final known = ids.where((id) => places.any((p) => p.id == id)).toSet();
      return AchievementProgress(known.where(visited.contains).length, known.length);
    }
    final pool = category == null ? places : places.where((p) => p.category == category).toList();
    final target = count ?? pool.length;
    final done = pool.where((p) => visited.contains(p.id)).length;
    return AchievementProgress(done > target ? target : done, target);
  }
}

class AchievementProgress {
  const AchievementProgress(this.done, this.target);

  final int done;
  final int target;

  bool get unlocked => target > 0 && done >= target;
  double get fraction => target == 0 ? 0 : done / target;
}

const achievements = <Achievement>[
  Achievement(
    id: 'first_step',
    title: 'Первый шаг',
    description: 'Посетить первое историческое место',
    icon: Icons.flag_outlined,
    count: 1,
  ),
  Achievement(
    id: 'detinets',
    title: 'Знаток Детинца',
    description: 'Обойти кремль: София, Грановитая палата, Кокуй и другие',
    icon: Icons.fort,
    placeIds: {'kremlin', 'sofia', 'millennium', 'granovitaya', 'kokuy', 'vhod_ierusalim'},
  ),
  Achievement(
    id: 'torgovaya',
    title: 'Торговая сторона',
    description: 'Ярославово дворище, торг, вече и храмы купцов',
    icon: Icons.storefront_outlined,
    placeIds: {'yaroslav', 'nikolsky', 'torg', 'veche', 'ilyina_spas', 'znamensky'},
  ),
  Achievement(
    id: 'bridge',
    title: 'Через Волхов',
    description: 'Перейти реку там, где стоял Великий мост',
    icon: Icons.water,
    placeIds: {'bridge'},
  ),
  Achievement(
    id: 'pilgrim',
    title: 'Паломник',
    description: 'Побывать у пяти храмов',
    icon: Icons.church_outlined,
    category: PlaceCategory.temple,
    count: 5,
  ),
  Achievement(
    id: 'monasteries',
    title: 'Монастырская тропа',
    description: 'Дойти до трёх монастырей',
    icon: Icons.hiking,
    category: PlaceCategory.monastery,
    count: 3,
  ),
  Achievement(
    id: 'lost',
    title: 'Память места',
    description: 'Увидеть места, которые город потерял или собрал заново',
    icon: Icons.history_edu,
    placeIds: {'lazar', 'desyatinny', 'nereditsa'},
  ),
  Achievement(
    id: 'suburbs',
    title: 'За городом',
    description: 'Юрьев монастырь, Витославлицы и Нередица',
    icon: Icons.forest_outlined,
    placeIds: {'yuriev', 'vitoslavlitsy', 'nereditsa'},
  ),
  Achievement(
    id: 'explorer',
    title: 'Исследователь',
    description: 'Посетить десять мест',
    icon: Icons.explore_outlined,
    count: 10,
  ),
  Achievement(
    id: 'keeper',
    title: 'Хранитель истории',
    description: 'Посетить все места из каталога',
    icon: Icons.workspace_premium_outlined,
  ),
];

Achievement? achievementById(String id) {
  for (final a in achievements) {
    if (a.id == id) return a;
  }
  return null;
}
