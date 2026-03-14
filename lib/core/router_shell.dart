part of 'router.dart';

class _GShell extends StatelessWidget {
  const _GShell({required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(
      label: 'Anchor',
      icon: Icons.wb_sunny_outlined,
      route: GRoutes.anchor,
    ),
    _TabItem(
      label: 'Daily 3',
      icon: Icons.checklist_rounded,
      route: GRoutes.daily3,
    ),
    _TabItem(
      label: 'Capture',
      icon: Icons.inbox_outlined,
      route: GRoutes.capture,
    ),
    _TabItem(
      label: 'Habit',
      icon: Icons.local_fire_department_outlined,
      route: GRoutes.habit,
    ),
    _TabItem(
      label: 'People',
      icon: Icons.people_outline_rounded,
      route: GRoutes.responsibility,
    ),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (var i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].route ||
          (_tabs[i].route != GRoutes.anchor &&
              location.startsWith(_tabs[i].route))) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: GColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex(context),
          onTap: (index) => context.go(_tabs[index].route),
          backgroundColor: GColors.background,
          selectedItemColor: GColors.orange,
          unselectedItemColor: GColors.textMuted,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: GText.label.copyWith(color: GColors.orange),
          unselectedLabelStyle: GText.label.copyWith(color: GColors.textMuted),
          elevation: 0,
          items: _tabs
              .map(
                (tab) => BottomNavigationBarItem(
                  icon: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Icon(tab.icon),
                  ),
                  label: tab.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(GSpacing.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: GColors.danger),
              const SizedBox(height: GSpacing.md),
              Text(
                GStrings.errorGeneric,
                style: GText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: GSpacing.lg),
              ElevatedButton(
                onPressed: () => context.go(GRoutes.anchor),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
