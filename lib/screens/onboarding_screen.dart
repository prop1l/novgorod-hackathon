import 'package:flutter/material.dart';

import '../main.dart';
import '../theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    (
      Icons.history_edu,
      'Новгород сквозь время',
      'Гуляйте по городу, которому больше 1150 лет, и узнавайте, что было на этом месте раньше.',
    ),
    (
      Icons.notifications_active,
      'Гид сам подскажет',
      'Проходите мимо Софийского собора или Ярославова дворища — и получите уведомление с историей и старым фото.',
    ),
    (
      Icons.location_on,
      'Нужна геолокация',
      'Чтобы гид работал, когда телефон в кармане, приложение следит за положением в фоне. '
          'Координаты никуда не отправляются — всё считается на телефоне. '
          'В шторке будет значок «Гид активен», выключить гид можно в настройках.',
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  Future<void> _finish({required bool requestPermissions}) async {
    final state = AppScope.read(context);
    if (requestPermissions) await state.requestAccess();
    state.storage.onboardingDone = true;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final (icon, title, text) = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundColor: AppColors.ochre.withValues(alpha: 0.2),
                          child: Icon(icon, size: 64, color: AppColors.cinnabar),
                        ),
                        const SizedBox(height: 32),
                        Text(title,
                            style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(text, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    width: i == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.cinnabar : AppColors.ochre,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _isLast
                        ? () => _finish(requestPermissions: true)
                        : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut),
                    child: Text(_isLast ? 'Разрешить и начать' : 'Далее'),
                  ),
                  if (_isLast)
                    TextButton(
                      onPressed: () => _finish(requestPermissions: false),
                      child: const Text('Пока без геолокации'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
