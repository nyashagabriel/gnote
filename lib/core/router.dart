import 'package:flutter/material.dart';
import 'package:gnote/pages/verify_opt_page.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_db.dart';
import '../pages/anchor_page.dart';
import '../pages/capture_page.dart';
import '../pages/daily3_page.dart';
import '../pages/habit_page.dart';
import '../pages/responsibility_page.dart';
import '../pages/add_tasks.dart';
import '../pages/add_persons.dart';
import '../pages/login_page.dart';
import '../pages/signup_page.dart';
import '../pages/profile_page.dart';
import 'constants.dart';

// ─────────────────────────────────────────────────────────────
// GNOTE — ROUTER (LIVE)
//
// Auth guard checks Supabase session on every redirect.
// Logged-out users hitting protected routes → /login
// Logged-in users hitting /login or /signup  → /
// ─────────────────────────────────────────────────────────────

const _publicRoutes = {GRoutes.login, GRoutes.signup};

// Routes that require today's anchor to be written first.
// Before 9am + no anchor today → redirect to /anchor regardless of which tab
// the user tries to navigate to.
// After 9am the anchor gate lifts — the day is already decided.
const _gatedRoutes = {
  GRoutes.daily3,
  GRoutes.capture,
  GRoutes.habit,
  GRoutes.responsibility,
};

String? _authGuard(GoRouterState state) {
  final loggedIn = Supabase.instance.client.auth.currentUser != null;
  final path = state.uri.path;
  final onPublic = _publicRoutes.contains(path);

  if (!loggedIn && !onPublic) return GRoutes.login;
  if (loggedIn && onPublic) return GRoutes.anchor;

  // ── Nav lock — Tendai's anchor gate ──────────────────────
  // Only applies to logged-in users, before 9am, on gated routes.
  if (loggedIn &&
      _gatedRoutes.any((r) => path == r || path.startsWith('$r/'))) {
    final before9am = DateTime.now().hour < 9;
    if (before9am && !LocalDb.instance.hasAnchorToday) {
      return GRoutes.anchor;
    }
  }

  return null;
}

final goRouter = GoRouter(
  initialLocation: GRoutes.anchor,
  debugLogDiagnostics: false,
  redirect: (_, state) => _authGuard(state),
  routes: [
    GoRoute(
      path: GRoutes.login,
      name: 'login',
      builder: (_, __) => const LoginPage(),
    ),
    GoRoute(
      path: GRoutes.signup,
      name: 'signup',
      builder: (_, __) => const SignupPage(),
    ),
    GoRoute(
      path: GRoutes.profile,
      name: 'profile',
      builder: (_, __) => const ProfilePage(),
    ),
    GoRoute(
      path: GRoutes.verifyOtp,
      name: 'verifyOtp',
      builder: (_, state) => VerifyOtpPage(
        email: state.uri.queryParameters['email'] ?? '',
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => _GShell(child: child),
      routes: [
        GoRoute(
          path: GRoutes.anchor,
          name: 'anchor',
          builder: (_, __) => const AnchorPage(),
        ),
        GoRoute(
          path: GRoutes.daily3,
          name: 'daily3',
          builder: (_, __) => const Daily3Page(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'addTask',
              builder: (_, __) => const AddTaskPage(),
            ),
          ],
        ),
        GoRoute(
          path: GRoutes.capture,
          name: 'capture',
          builder: (_, __) => const CapturePage(),
        ),
        GoRoute(
          path: GRoutes.habit,
          name: 'habit',
          builder: (_, __) => const HabitPage(),
        ),
        GoRoute(
          path: GRoutes.responsibility,
          name: 'responsibility',
          builder: (_, __) => const ResponsibilityPage(),
          routes: [
            GoRoute(
              path: 'add',
              name: 'addPerson',
              builder: (_, __) => const AddPersonPage(),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => _ErrorScreen(error: state.error),
);

// ─────────────────────────────────────────────────────────────
// SHELL — Bottom Navigation Wrapper
// ─────────────────────────────────────────────────────────────

class _GShell extends StatelessWidget {
  const _GShell({required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem(
        label: 'Anchor', icon: Icons.wb_sunny_outlined, route: GRoutes.anchor),
    _TabItem(
        label: 'Daily 3', icon: Icons.checklist_rounded, route: GRoutes.daily3),
    _TabItem(
        label: 'Capture', icon: Icons.inbox_outlined, route: GRoutes.capture),
    _TabItem(
        label: 'Habit',
        icon: Icons.local_fire_department_outlined,
        route: GRoutes.habit),
    _TabItem(
        label: 'People',
        icon: Icons.people_outline_rounded,
        route: GRoutes.responsibility),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
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
          onTap: (i) => context.go(_tabs[i].route),
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
              .map((t) => BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Icon(t.icon),
                    ),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem(
      {required this.label, required this.icon, required this.route});
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
              Text(GStrings.errorGeneric,
                  style: GText.body, textAlign: TextAlign.center),
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
