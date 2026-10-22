import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../theme.dart';
import 'home_screen.dart';

/// Онбординг из Figma: два светлых слайда и тёмный экран запроса геолокации.
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
      'Здесь было…',
      'Гуляйте по городу, которому больше 1150 лет, и узнавайте, что было на этом месте раньше.',
    ),
    (
      'Гид сам подскажет',
      'Телефон можно не доставать: пришлём уведомление, когда будете проходить мимо интересного места.',
    ),
  ];

  static const _pageCount = 3;

  void _goTo(int page) => _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

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
    final dark = _page == _pageCount - 1;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: dark ? AppColors.bgDark : AppColors.bgLight,
        body: PageView(
          controller: _controller,
          onPageChanged: (i) => setState(() => _page = i),
          children: [
            for (var i = 0; i < _slides.length; i++)
              _Slide(
                title: _slides[i].$1,
                text: _slides[i].$2,
                page: i,
                pageCount: _pageCount,
                onSkip: () => _goTo(_pageCount - 1),
                onNext: () => _goTo(i + 1),
              ),
            _PermissionPage(
              onAllow: () => _finish(requestPermissions: true),
              onLater: () => _finish(requestPermissions: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.title,
    required this.text,
    required this.page,
    required this.pageCount,
    required this.onSkip,
    required this.onNext,
  });

  final String title;
  final String text;
  final int page;
  final int pageCount;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 12, 30, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onSkip,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.w500),
                ),
                child: const Text('Пропустить'),
              ),
            ),
            const Spacer(),
            Text(title, style: AppText.h1),
            const SizedBox(height: 12),
            Text(text, style: AppText.body.copyWith(fontSize: 18)),
            const Spacer(),
            Row(
              children: [
                for (var i = 0; i < pageCount; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    width: 26,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == page ? AppColors.accent : AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(minimumSize: const Size(160, 62)),
                  child: const Text('Дальше'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionPage extends StatelessWidget {
  const _PermissionPage({required this.onAllow, required this.onLater});

  final VoidCallback onAllow;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 40, 30, 24),
        child: Column(
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.location_on, size: 110, color: Colors.black),
            ),
            const SizedBox(height: 32),
            Text(
              'Чтобы напоминать о местах рядом, нужна геолокация «Всегда»',
              textAlign: TextAlign.center,
              style: AppText.h2.copyWith(color: AppColors.onDark, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
              child: Text(
                'Без неё приложение работает, но узнаёт о месте, только когда вы его откроете. '
                'Координаты не покидают телефон.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppColors.onDark),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: onAllow, child: const Text('Разрешить')),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onLater,
              style: TextButton.styleFrom(foregroundColor: AppColors.onDark),
              child: const Text('Не сейчас'),
            ),
          ],
        ),
      ),
    );
  }
}
