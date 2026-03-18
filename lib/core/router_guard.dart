part of 'router.dart';

const _publicRoutes = {GRoutes.onboarding, GRoutes.login, GRoutes.signup};

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
  final seenOnboarding = LocalDb.instance.hasSeenOnboarding();

  if (!loggedIn && !seenOnboarding && path != GRoutes.onboarding) {
    return GRoutes.onboarding;
  }
  if (!loggedIn && !onPublic) return GRoutes.login;
  if (loggedIn && onPublic) return GRoutes.anchor;

  if (_requiresAnchor(path) &&
      _isBeforeAnchorLock() &&
      !LocalDb.instance.hasAnchorToday) {
    return GRoutes.anchor;
  }

  return null;
}

bool _requiresAnchor(String path) {
  return _gatedRoutes
      .any((route) => path == route || path.startsWith('$route/'));
}

bool _isBeforeAnchorLock() {
  return localNow().hour < 9;
}
