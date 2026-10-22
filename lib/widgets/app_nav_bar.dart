import 'package:flutter/material.dart';

import '../theme.dart';

/// Нижняя навигация из Figma: тёмная панель, у активной вкладки — синяя «пилюля».
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  static const _tabs = [
    (Icons.map_outlined, 'Карта'),
    (Icons.list_alt, 'Места'),
    (Icons.settings_outlined, 'Настройки'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 12 + MediaQuery.paddingOf(context).bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            Expanded(
              child: InkResponse(
                onTap: () => onSelect(i),
                radius: 48,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      decoration: BoxDecoration(
                        color: i == selected ? AppColors.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(_tabs[i].$1, color: AppColors.onDark, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tabs[i].$2,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onDark,
                        fontWeight: i == selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
