// ==========================================
// FILE: ./pages/login_page.dart
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../services/providers.dart';
import '../services/notification_service.dart';
import '../services/local_db.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool    _obscure    = true;
  bool    _loading    = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passwordCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = GStrings.authEmptyFieldsErr);
      return;
    }

    setState(() { _loading = true; _error = null; });

    final error = await ref.read(authProvider.notifier).signIn(email, pass);

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      final reminder = LocalDb.instance.getHabitReminderTime();
      await NotificationService.ensurePermissionAndScheduleAll(
        habitHour: reminder.hour,
        habitMinute: reminder.minute,
      );
      if (!mounted) return;
      context.go(GRoutes.anchor);
      return;
    }

    // Dynamic reroute
    if (error.contains('confirm your email first')) {
      context.go('${GRoutes.verifyOtp}?email=$email');
      return;
    }

    setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(GSpacing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(GStrings.appName.toUpperCase(), style: GText.heading.copyWith(color: GColors.orange, fontSize: 32, letterSpacing: 1.2)),
                Container(margin: const EdgeInsets.symmetric(vertical: GSpacing.xs), height: 2, width: 80, color: GColors.orange),
                Text(GStrings.appTagline, style: GText.muted.copyWith(fontSize: 14)),
                const SizedBox(height: GSpacing.xxl),
                
                Text(GStrings.authSignIn, style: GText.label),
                const SizedBox(height: GSpacing.lg),

                Text(GStrings.authEmailLabel, style: GText.muted),
                const SizedBox(height: GSpacing.sm),
                TextField(
                  key: const Key('login_email_input'),
                  controller: _emailCtrl, style: GText.body, keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: GStrings.authEmailHint, hintStyle: GText.body.copyWith(color: GColors.textDisabled),
                    filled: true, fillColor: GColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(GSpacing.inputRadius), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(GSpacing.inputRadius), borderSide: const BorderSide(color: GColors.orange, width: 1.5)),
                  ),
                ),
                const SizedBox(height: GSpacing.md),

                Text(GStrings.authPasswordLabel, style: GText.muted),
                const SizedBox(height: GSpacing.sm),
                TextField(
                  key: const Key('login_password_input'),
                  controller: _passwordCtrl, style: GText.body, obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: GStrings.authPasswordHint, hintStyle: GText.body.copyWith(color: GColors.textDisabled),
                    filled: true, fillColor: GColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(GSpacing.inputRadius), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(GSpacing.inputRadius), borderSide: const BorderSide(color: GColors.orange, width: 1.5)),
                    suffixIcon: IconButton(
                      key: const Key('login_password_visibility_toggle'),
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: GColors.textMuted, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),

                const SizedBox(height: GSpacing.sm),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: _error != null
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(bottom: GSpacing.sm),
                          child: Text(_error!, key: const Key('login_error_text'), style: GText.danger),
                        )
                      : const SizedBox(width: double.infinity, height: 8),
                ),

                const SizedBox(height: GSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('login_submit_button'),
                    onPressed: _loading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GColors.orange,
                      disabledBackgroundColor: GColors.surfaceHigh,
                      padding: const EdgeInsets.symmetric(vertical: GSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GSpacing.buttonRadius)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: GColors.background, strokeWidth: 2))
                        : Text(GStrings.authSignIn, style: GText.subheading.copyWith(color: GColors.background, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: GSpacing.md),
                
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(GStrings.authNoAccountPrompt, style: GText.muted),
                      TextButton(
                        key: const Key('login_to_signup_link'),
                        onPressed: () => context.go(GRoutes.signup),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          GStrings.authSignUp,
                          style: GText.muted.copyWith(color: GColors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
