import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/timezone.dart';
import '../../models/user.dart';
import '../auth_service.dart';
import '../local_db.dart';
import '../sync.dart';
import 'core_providers.dart';

sealed class AuthActionResult {
  const AuthActionResult();
}

class AuthSuccess extends AuthActionResult {
  const AuthSuccess();
}

class AuthFailure extends AuthActionResult {
  const AuthFailure(this.message);

  final String message;
}

class AuthNeedsVerification extends AuthActionResult {
  const AuthNeedsVerification(this.email);

  final String email;
}

String _authError(Object e, {required bool isSignUp}) {
  if (e is AuthException) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Check your inbox — confirm your email first.';
    }
    if (msg.contains('invalid email')) {
      return 'That email address is not valid.';
    }
    if (msg.contains('password should be')) {
      return 'Password must be at least 6 characters.';
    }
    if (msg.contains('weak password')) {
      return 'Password is too weak. Add numbers or symbols.';
    }
    if (msg.contains('token has expired') || msg.contains('expired')) {
      return 'That code has expired. Please request a new one.';
    }
    if (msg.contains('invalid otp') || msg.contains('token')) {
      return 'Invalid code. Please check and try again.';
    }
    if (isSignUp) {
      if (msg.contains('already registered') ||
          msg.contains('already been registered') ||
          msg.contains('user already exists')) {
        return 'An account with that email already exists. Sign in instead.';
      }
    }
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return 'Too many attempts. Wait a moment and try again.';
    }
    return e.message;
  }

  final str = e.toString().toLowerCase();
  if (str.contains('socketexception') ||
      str.contains('connection refused') ||
      str.contains('network is unreachable') ||
      str.contains('failed host lookup') ||
      str.contains('no address associated') ||
      str.contains('connection timed out') ||
      str.contains('handshake') ||
      str.contains('clientexception')) {
    return 'No internet connection. Check your network and try again.';
  }

  if (str.contains('supabaseurl') ||
      str.contains('supabaseclient') ||
      str.contains('not initialized')) {
    return 'App is not configured. Contact support.';
  }

  return 'Something went wrong. Please try again.';
}

void _logAuthFallback(String context, Object error, [StackTrace? stackTrace]) {
  debugPrint('Auth fallback [$context]: $error');
  if (stackTrace != null) {
    debugPrintStack(stackTrace: stackTrace);
  }
}

class AuthNotifier extends StateNotifier<AsyncValue<GUser?>> {
  AuthNotifier(this._auth, this._db, this._sync)
      : super(const AsyncValue.loading()) {
    _init();
  }

  final AuthService _auth;
  final LocalDb _db;
  final SyncService _sync;

  void _init() {
    final user = _auth.currentUser;
    if (user == null) {
      state = const AsyncValue.data(null);
      return;
    }
    _loadProfileSafely();
  }

  Future<void> _loadProfileSafely() async {
    try {
      final profile = await _auth.fetchProfile();
      if (profile != null) {
        await _db.saveCurrentUser(profile);
      }
      state = AsyncValue.data(profile);
    } catch (e, stackTrace) {
      _logAuthFallback('loadProfile', e, stackTrace);
      final sessionUser = _auth.currentUser;
      if (sessionUser == null) {
        state = const AsyncValue.data(null);
        return;
      }
      final fallback = GUser(
        id: sessionUser.id,
        email: sessionUser.email ?? '',
        displayName: sessionUser.userMetadata?['display_name'] as String? ?? '',
        timezone: deviceTimezone(),
        createdAt: localNow(),
        lastSeen: localNow(),
      );
      await _db.saveCurrentUser(fallback);
      state = AsyncValue.data(fallback);
    }
  }

  Future<AuthActionResult> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _auth.signIn(email: email, password: password);
      if (user == null) {
        state = const AsyncValue.data(null);
        return const AuthFailure('Incorrect email or password.');
      }
      await _sync.pullAll();
      await _db.saveCurrentUser(user);
      state = AsyncValue.data(user);
      return const AuthSuccess();
    } catch (e) {
      state = const AsyncValue.data(null);
      if (e is AuthException &&
          e.message.toLowerCase().contains('email not confirmed')) {
        return AuthNeedsVerification(email);
      }
      return AuthFailure(_authError(e, isSignUp: false));
    }
  }

  Future<AuthActionResult> signUp(
    String email,
    String password,
    String name,
  ) async {
    state = const AsyncValue.loading();
    try {
      final outcome = await _auth.signUp(
        email: email,
        password: password,
        displayName: name,
      );
      switch (outcome) {
        case SignUpSessionActive(:final user):
          await _sync.pullAll();
          await _db.saveCurrentUser(user);
          state = AsyncValue.data(user);
          return const AuthSuccess();
        case SignUpNeedsVerification(:final email):
          state = const AsyncValue.data(null);
          return AuthNeedsVerification(email);
        case SignUpFailed(:final message):
          state = const AsyncValue.data(null);
          return AuthFailure(message);
      }
    } catch (e) {
      state = const AsyncValue.data(null);
      return AuthFailure(_authError(e, isSignUp: true));
    }
  }

  Future<AuthActionResult> verifyOTP(String email, String token) async {
    state = const AsyncValue.loading();
    try {
      final user = await _auth.verifyOTP(email: email, token: token);
      if (user == null) {
        state = const AsyncValue.data(null);
        return const AuthFailure('Verification failed. Please try again.');
      }

      await _sync.pullAll();
      await _db.saveCurrentUser(user);
      state = AsyncValue.data(user);
      return const AuthSuccess();
    } catch (e) {
      state = const AsyncValue.data(null);
      return AuthFailure(_authError(e, isSignUp: false));
    }
  }

  Future<AuthActionResult> resendOTP(String email) async {
    try {
      await _auth.resendOTP(email: email);
      return const AuthSuccess();
    } catch (e) {
      return AuthFailure(_authError(e, isSignUp: false));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _db.clearAll();
    } catch (e, stackTrace) {
      _logAuthFallback('signOut.clearAll', e, stackTrace);
    }
    state = const AsyncValue.data(null);
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.updateDisplayName(name);
    await _loadProfileSafely();
  }

  Future<void> updateTimezone(String timezone) async {
    await _auth.updateTimezone(timezone);
    await _loadProfileSafely();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<GUser?>>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(localDbProvider),
    ref.watch(syncServiceProvider),
  );
});

final currentUserProvider = Provider<GUser?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});
