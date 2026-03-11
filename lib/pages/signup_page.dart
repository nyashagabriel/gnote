// ==========================================
// FILE: ./pages/signup_page.dart
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../services/providers.dart';
import '../services/notification_service.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});
  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool    _obscure         = true;
  bool    _loading         = false;
  String? _error;

  int get _strength {
    final p = _passwordCtrl.text;
    int s = 0;
    if (p.length >= 8)                            s++;
    if (p.contains(RegExp(r'[A-Z]')))             s++;
    if (p.contains(RegExp(r'[0-9]')))             s++;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?]'))) s++;
    return s;
  }

  String get _strengthLabel => switch (_strength) {
    0 || 1 => GStrings.authWeak,
    2      => GStrings.authMod,
    3      => GStrings.authStrong,
    _      => GStrings.authVeryStrong,
  };

  Color _strengthColor(int index) {
    if (index >= _strength) return GColors.surfaceHigh;
    return switch (_strength) {
      1 => GColors.danger,
      2 => GColors.orange,
      3 => GColors.warning,
      _ => GColors.success,
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name  = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass  = _passwordCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = GStrings.authReqFields);
      return;
    }
    if (_strength < 2) {
      setState(() => _error = GStrings.authWeakPass);
      return;
    }

    setState(() { _loading = true; _error = null; });
    final result = await ref.read(authProvider.notifier).signUp(email, pass, name);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result == null) {
      await NotificationService.scheduleAll();
      if (!mounted) return;
      context.go(GRoutes.anchor);
      return;
    }

    if (result.startsWith('VERIFY:')) {
      final userEmail = result.substring(7);
      context.go('${GRoutes.verifyOtp}?email=$userEmail');
      return;
    }

    setState(() => _error = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: GSpacing.md),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.canPop() ? context.pop() : context.go(GRoutes.login),
                    child: Container(
                      padding: const EdgeInsets.all(GSpacing.sm),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: GColors.surface),
                      child: const Icon(Icons.arrow_back, color: GColors.textPrimary, size: 18),
                    ),
                  ),
                  const SizedBox(width: GSpacing.sm),
                  Text(GStrings.authSignUp, style: GText.label.copyWith(fontSize: 14, color: GColors.textPrimary)),
                ],
              ),
              const SizedBox(height: GSpacing.lg),
              Text(GStrings.appName.toUpperCase(), style: GText.heading.copyWith(color: GColors.orange, fontSize: 32, letterSpacing: 1.2)),
              Container(margin: const EdgeInsets.symmetric(vertical: GSpacing.xs), height: 2, width: 80, color: GColors.orange),
              Text(GStrings.appTagline, style: GText.muted.copyWith(fontSize: 14)),
              const SizedBox(height: GSpacing.xl),
              
              Text(GStrings.authCreateAccount, style: GText.label),
              const SizedBox(height: GSpacing.lg),

              Text(GStrings.authDisplayName, style: GText.muted),
              const SizedBox(height: GSpacing.sm),
              _field(_nameCtrl, GStrings.authNameHint),
              const SizedBox(height: GSpacing.md),

              Text(GStrings.authEmailLabel, style: GText.muted),
              const SizedBox(height: GSpacing.sm),
              _field(_emailCtrl, GStrings.authEmailHint, type: TextInputType.emailAddress),
              const SizedBox(height: GSpacing.md),

              Text(GStrings.authPasswordLabel, style: GText.muted),
              const SizedBox(height: GSpacing.sm),
              TextField(
                controller: _passwordCtrl,
                style: GText.body,
                obscureText: _obscure,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: GStrings.authPasswordHint,
                  hintStyle: GText.body.copyWith(color: GColors.textDisabled),
                  filled: true, fillColor: GColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(GSpacing.inputRadius), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(GSpacing.inputRadius), borderSide: const BorderSide(color: GColors.orange, width: 1.5)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: GColors.textMuted, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (_passwordCtrl.text.isNotEmpty) ...[
                const SizedBox(height: GSpacing.sm),
                Row(children: List.generate(4, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                    decoration: BoxDecoration(color: _strengthColor(i), borderRadius: BorderRadius.circular(2)),
                  ),
                ))),
                const SizedBox(height: GSpacing.xs),
                Text('${GStrings.authStrength}$_strengthLabel', style: GText.label.copyWith(fontSize: 10)),
              ],

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _error != null ? 40 : 8,
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: GSpacing.sm),
                        child: Text(_error!, style: GText.danger),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: GSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GColors.orange,
                    disabledBackgroundColor: GColors.surfaceHigh,
                    padding: const EdgeInsets.symmetric(vertical: GSpacing.md),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GSpacing.buttonRadius)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: GColors.background, strokeWidth: 2))
                      : Text(GStrings.authCreateAccount, style: GText.subheading.copyWith(color: GColors.background, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: GSpacing.md),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(GStrings.authHasAccountPrompt, style: GText.muted),
                    GestureDetector(
                      onTap: () => context.go(GRoutes.login),
                      child: Text(GStrings.authSignIn, style: GText.muted.copyWith(color: GColors.orange)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl, style: GText.body, keyboardType: type,
      decoration: InputDecoration(
        hintText: hint, hintStyle: GText.body.copyWith(color: GColors.textDisabled),
        filled: true, fillColor: GColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(GSpacing.inputRadius), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(GSpacing.inputRadius), borderSide: const BorderSide(color: GColors.orange, width: 1.5)),
      ),
    );
  }
}