import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../services/local_db.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    (
      title: 'Start your day on purpose',
      body: 'Anchor the day with one honest sentence before everything else.'
    ),
    (
      title: 'Three tasks. One habit. One reach-out.',
      body:
          'Gnote cuts the noise. Daily 3, Capture, one Habit, and one daily person to reach.'
    ),
    (
      title: 'Built for constraint, not clutter',
      body:
          'The app limits choices on purpose so the important things stay visible.'
    ),
  ];

  Future<void> _finish(String route) async {
    await LocalDb.instance.markOnboardingSeen();
    if (!mounted) return;
    context.go(route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;

    return Scaffold(
      backgroundColor: GColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(GSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _finish(GRoutes.login),
                  child: Text(
                    GStrings.authSignIn,
                    style: GText.muted.copyWith(color: GColors.textMuted),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            GStrings.appName.toUpperCase(),
                            style: GText.label.copyWith(
                              color: GColors.orange,
                              fontSize: 14,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: GSpacing.md),
                          Text(
                            page.title,
                            style: GText.heading.copyWith(fontSize: 34),
                          ),
                          const SizedBox(height: GSpacing.md),
                          Text(
                            page.body,
                            style: GText.muted.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: List.generate(
                  _pages.length,
                  (i) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < _pages.length - 1 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i == _index ? GColors.orange : GColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: GSpacing.xl),
              if (!last)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _controller.nextPage(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    ),
                    child: const Text('Continue'),
                  ),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _finish(GRoutes.signup),
                        child: const Text(GStrings.authCreateAccount),
                      ),
                    ),
                    const SizedBox(height: GSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _finish(GRoutes.login),
                        child: const Text(GStrings.authSignIn),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
