import 'package:flutter/material.dart';
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
import '../pages/verify_opt_page.dart';
import 'constants.dart';
import 'timezone.dart';

part 'router_guard.dart';
part 'router_shell.dart';

final goRouter = GoRouter(
  initialLocation: GRoutes.anchor,
  debugLogDiagnostics: false,
  redirect: (_, state) => _authGuard(state),
  routes: _appRoutes,
  errorBuilder: (context, state) => _ErrorScreen(error: state.error),
);

final _appRoutes = <RouteBase>[
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
];
