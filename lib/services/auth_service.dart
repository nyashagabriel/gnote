import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/timezone.dart';
import '../models/user.dart';

// ─────────────────────────────────────────────────────────────
// GNOTE — AUTH SERVICE
// ─────────────────────────────────────────────────────────────

// ── SignUp outcome — three real states ────────────────────────
//
// Supabase signUp() has two valid success paths:
//
//   1. session != null → email confirmation disabled in Supabase.
//      User is fully logged in. Navigate to home.
//
//   2. session == null, user != null → email confirmation enabled.
//      User was created. They must verify before they can log in.
//      Show "Check your inbox" — do NOT treat this as an error.
//
//   3. user == null → signup genuinely failed (duplicate, bad input).
//      Surface the AuthException.
//
// The manual profile upsert is SKIPPED when session == null because:
//   a) RLS will reject an unauthenticated write — that's what caused
//      the "Something went wrong" error despite the user being created.
//   b) The handle_new_user trigger already inserts the profile row
//      the moment auth.users gets the new row.
// ─────────────────────────────────────────────────────────────

sealed class SignUpOutcome {}

class SignUpSessionActive extends SignUpOutcome {
  final GUser user;
  SignUpSessionActive(this.user);
}

class SignUpNeedsVerification extends SignUpOutcome {
  final String email;
  SignUpNeedsVerification(this.email);
}

class SignUpFailed extends SignUpOutcome {
  final String message;
  SignUpFailed(this.message);
}

// ─────────────────────────────────────────────────────────────

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _client = Supabase.instance.client;

  // ── Current session user ───────────────────────────────────
  User? get currentUser => _client.auth.currentUser;
  bool  get isLoggedIn  => currentUser != null;

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  // ── Sign Up ────────────────────────────────────────────────
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.auth.signUp(
      email:    email,
      password: password,
      data:     {'display_name': displayName},
    );

    // No user at all → Supabase rejected the signup outright
    if (response.user == null) {
      return SignUpFailed('Signup failed. Please try again.');
    }

    // session == null → email confirmation required.
    // User row created in auth.users, trigger fires, profile row created.
    // Do NOT attempt any DB writes here — there is no session, RLS will reject.
    if (response.session == null) {
      return SignUpNeedsVerification(email);
    }

    // session != null → confirmation disabled, user is fully logged in.
    // Upsert profile manually (trigger may not have run yet on some configs).
    final gUser = GUser(
      id:          response.user!.id,
      email:       email,
      displayName: displayName,
      timezone:    deviceTimezone(),
      createdAt:   DateTime.now(),
      lastSeen:    DateTime.now(),
    );

    try {
      await _client.from('profiles').upsert(gUser.toJson());
    } catch (_) {
      // Trigger already created the row — upsert failure is non-fatal.
    }

    return SignUpSessionActive(gUser);
  }

  // ── Verify OTP ─────────────────────────────────────────────
  Future<GUser?> verifyOTP({
    required String email,
    required String token,
  }) async {
    final response = await _client.auth.verifyOTP(
      type: OtpType.signup,
      token: token,
      email: email,
    );

    if (response.user == null || response.session == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .maybeSingle();

    if (data != null) {
      return GUser.fromJson(data);
    }

    // Fallback if the database trigger didn't run in time
    final fallback = GUser(
      id:          response.user!.id,
      email:       email,
      displayName: response.user!.userMetadata?['display_name'] as String? ?? '',
      timezone:    deviceTimezone(),
      createdAt:   DateTime.now(),
      lastSeen:    DateTime.now(),
    );

    try {
      await _client.from('profiles').upsert(fallback.toJson());
    } catch (_) {}

    return fallback;
  }

  // ── Resend OTP ─────────────────────────────────────────────
  Future<void> resendOTP({required String email}) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  // ── Sign In ────────────────────────────────────────────────
  Future<GUser?> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email:    email,
      password: password,
    );

    if (response.user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', response.user!.id)
        .single();

    // Update last seen — non-fatal if it fails
    try {
      await _client
          .from('profiles')
          .update({'last_seen': DateTime.now().toIso8601String()})
          .eq('id', response.user!.id);
    } catch (_) {}

    return GUser.fromJson(data);
  }

  // ── Sign Out ───────────────────────────────────────────────
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Update display name ────────────────────────────────────
  Future<void> updateDisplayName(String name) async {
    if (currentUser == null) return;
    await _client
        .from('profiles')
        .update({'display_name': name})
        .eq('id', currentUser!.id);
  }

  // ── Update timezone ────────────────────────────────────────
  Future<void> updateTimezone(String timezone) async {
    if (currentUser == null) return;
    await _client
        .from('profiles')
        .update({'timezone': timezone})
        .eq('id', currentUser!.id);
  }

  // ── Fetch profile ──────────────────────────────────────────
  Future<GUser?> fetchProfile() async {
    if (currentUser == null) return null;
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .single();
    return GUser.fromJson(data);
  }
}
