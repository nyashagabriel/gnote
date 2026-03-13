// ==========================================
// FILE: ./pages/verify_opt_page.dart
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../services/providers.dart';
import '../services/notification_service.dart';
import '../services/local_db.dart';

class VerifyOtpPage extends ConsumerStatefulWidget {
  final String email;
  const VerifyOtpPage({super.key, required this.email});

  @override
  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;
  String? _successMsg;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _otpCtrl.text.trim();
    if (code.length < 8) {
      setState(() => _error = GStrings.otpReqCode);
      return;
    }

    setState(() { _loading = true; _error = null; _successMsg = null; });
    final error = await ref.read(authProvider.notifier).verifyOTP(widget.email, code);

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
    } else {
      setState(() => _error = error);
    }
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _error = null; _successMsg = null; });
    final error = await ref.read(authProvider.notifier).resendOTP(widget.email);
    
    if (!mounted) return;
    setState(() {
      _resending = false;
      if (error == null) {
        _successMsg = GStrings.otpNewCodeSent;
      } else {
        _error = error;
      }
    });
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
              IconButton(
                onPressed: () => context.go(GRoutes.login),
                style: IconButton.styleFrom(
                  backgroundColor: GColors.surface,
                ),
                icon: const Icon(Icons.arrow_back,
                    color: GColors.textPrimary, size: 18),
              ),
              const SizedBox(height: GSpacing.xl),
              
              Text(GStrings.otpCheckInbox, style: GText.label.copyWith(color: GColors.orange)),
              const SizedBox(height: GSpacing.sm),
              Text(GStrings.otpEnterCode, style: GText.heading),
              const SizedBox(height: GSpacing.sm),
              RichText(
                text: TextSpan(
                  style: GText.body.copyWith(color: GColors.textMuted),
                  children: [
                    const TextSpan(text: GStrings.otpSentCode),
                    TextSpan(text: widget.email, style: const TextStyle(color: GColors.textPrimary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: GSpacing.xxl),

              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 8,
                textAlign: TextAlign.center,
                style: GText.heading.copyWith(fontSize: 32, letterSpacing: 16.0, color: GColors.orange),
                onChanged: (val) {
                  if (val.length == 8) _verify();
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  counterText: '',
                  hintText: GStrings.otpCodeHint,
                  hintStyle: GText.heading.copyWith(fontSize: 32, letterSpacing: 16.0, color: GColors.surfaceHigh),
                  filled: true,
                  fillColor: GColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: GSpacing.lg),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(GSpacing.inputRadius), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GSpacing.inputRadius),
                    borderSide: const BorderSide(color: GColors.orange, width: 2.0),
                  ),
                ),
              ),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: (_error != null || _successMsg != null) ? 40 : 16,
                padding: const EdgeInsets.only(top: GSpacing.sm),
                child: _error != null
                    ? Text(_error!, textAlign: TextAlign.center, style: GText.danger)
                    : _successMsg != null
                        ? Text(_successMsg!, textAlign: TextAlign.center, style: GText.body.copyWith(color: GColors.success))
                        : const SizedBox.shrink(),
              ),

              const SizedBox(height: GSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GColors.orange,
                    disabledBackgroundColor: GColors.surfaceHigh,
                    padding: const EdgeInsets.symmetric(vertical: GSpacing.md),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GSpacing.buttonRadius)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: GColors.background, strokeWidth: 2))
                      : Text(GStrings.otpVerifyBtn, style: GText.subheading.copyWith(color: GColors.background, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: GSpacing.xl),
              
              Center(
                child: _resending
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: GColors.azure, strokeWidth: 2))
                    : TextButton(
                        onPressed: _resend,
                        child: Text(GStrings.otpResendBtn, style: GText.label.copyWith(color: GColors.azure)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
