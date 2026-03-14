// ==========================================
// FILE: ./pages/profile_page.dart
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../core/timezone.dart';
import '../models/user.dart';
import '../services/local_db.dart';
import '../services/notification_service.dart';
import '../services/providers.dart';

part 'profile_page_sections.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _signingOut = false;
  final _db = LocalDb.instance;
  TimeOfDay _habitTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    final reminder = _db.getHabitReminderTime();
    _habitTime = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
  }

  void _logProfileIssue(String context, Object error,
      [StackTrace? stackTrace]) {
    debugPrint('ProfilePage issue [$context]: $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: GColors.danger,
        content: Text(message, style: GText.body),
      ),
    );
  }

  Future<void> _pickHabitTime() async {
    try {
      final picked = await showTimePicker(
        context: context,
        initialTime: _habitTime,
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: GColors.orange,
                surface: GColors.surface,
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: GColors.surface,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      );

      if (picked == null || !mounted) return;

      setState(() => _habitTime = picked);
      await _db.saveHabitReminderTime(picked.hour, picked.minute);
      final updated = await NotificationService.updateHabitTime(
        picked.hour,
        picked.minute,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: updated ? GColors.surface : GColors.danger,
          content: Text(
            updated
                ? '${GStrings.profileHabitSetSnack}${picked.format(context)}'
                : GStrings.profileHabitErrSnack,
            style: GText.body,
          ),
        ),
      );
    } catch (e, stackTrace) {
      _logProfileIssue('pickHabitTime', e, stackTrace);
      _showErrorSnack(GStrings.profileHabitErrSnack);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await _confirmSignOut();

    if (!confirmed || !mounted) return;

    setState(() => _signingOut = true);

    try {
      await NotificationService.cancelAll();
      await ref.read(authProvider.notifier).signOut();

      if (!mounted) return;
      context.go(GRoutes.login);
    } catch (e, stackTrace) {
      _logProfileIssue('signOut', e, stackTrace);
      if (!mounted) return;
      setState(() => _signingOut = false);
      _showErrorSnack(GStrings.profileSignOutErr);
    }
  }

  Future<void> _pickThemeMode() async {
    final current = ref.read(themeModeProvider);
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: GColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text(GStrings.profileThemeSystem),
            trailing: current == ThemeMode.system
                ? const Icon(Icons.check, color: GColors.orange)
                : null,
            onTap: () => Navigator.pop(context, ThemeMode.system),
          ),
          ListTile(
            title: const Text(GStrings.profileThemeLight),
            trailing: current == ThemeMode.light
                ? const Icon(Icons.check, color: GColors.orange)
                : null,
            onTap: () => Navigator.pop(context, ThemeMode.light),
          ),
          ListTile(
            title: const Text(GStrings.profileThemeDark),
            trailing: current == ThemeMode.dark
                ? const Icon(Icons.check, color: GColors.orange)
                : null,
            onTap: () => Navigator.pop(context, ThemeMode.dark),
          ),
          const SizedBox(height: GSpacing.md),
        ],
      ),
    );
    if (selected == null) return;
    await ref.read(themeModeProvider.notifier).setThemeMode(selected);
  }

  Future<bool> _confirmSignOut() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              backgroundColor: GColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(GSpacing.cardRadius),
                side: const BorderSide(color: GColors.border),
              ),
              title:
                  Text(GStrings.profileSignOutTitle, style: GText.subheading),
              content: Text(
                GStrings.profileSignOutSub,
                style: GText.body,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(GStrings.cancel, style: GText.muted),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(
                    GStrings.profileSignOutBtn,
                    style: GText.danger.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final viewData = _ProfileViewData.fromUser(
      user: user,
      themeMode: themeMode,
    );

    return Scaffold(
      backgroundColor: GColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _ProfileHeader(
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.go(GRoutes.anchor);
              },
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  GSpacing.pagePadding,
                  0,
                  GSpacing.pagePadding,
                  GSpacing.pagePadding,
                ),
                children: [
                  _ProfileHeroCard(
                    initials: viewData.initials,
                    displayName: viewData.displayName,
                    email: viewData.email,
                  ),
                  const SizedBox(height: GSpacing.xl),
                  const _SectionTitle(GStrings.profileSecAccount),
                  const SizedBox(height: GSpacing.sm),
                  _CardSection(
                    children: [
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: GStrings.profileDisplayName,
                        value: viewData.displayName,
                      ),
                      const _SectionDivider(),
                      _InfoRow(
                        icon: Icons.alternate_email_rounded,
                        label: GStrings.profileEmail,
                        value: viewData.email,
                      ),
                      const _SectionDivider(),
                      _InfoRow(
                        icon: Icons.public_outlined,
                        label: GStrings.profileTimezone,
                        value: viewData.timezone,
                      ),
                    ],
                  ),
                  const SizedBox(height: GSpacing.xl),
                  const _SectionTitle(GStrings.profileSecPrefs),
                  const SizedBox(height: GSpacing.sm),
                  _CardSection(
                    children: [
                      _ActionRow(
                        icon: Icons.palette_outlined,
                        label: GStrings.profileThemeMode,
                        value: viewData.themeLabel,
                        accent: GColors.azure,
                        onTap: _pickThemeMode,
                      ),
                      const _SectionDivider(),
                      _ActionRow(
                        icon: Icons.access_time_rounded,
                        label: GStrings.profileHabitRem,
                        value: _habitTime.format(context),
                        accent: GColors.orange,
                        onTap: _pickHabitTime,
                      ),
                    ],
                  ),
                  const SizedBox(height: GSpacing.xl),
                  const _SectionTitle(GStrings.profileSecSession),
                  const SizedBox(height: GSpacing.sm),
                  _CardSection(
                    children: [
                      _DangerRow(
                        icon: Icons.logout_rounded,
                        label: GStrings.profileSignOutBtn,
                        loading: _signingOut,
                        onTap: _signingOut ? null : _signOut,
                      ),
                    ],
                  ),
                  const SizedBox(height: GSpacing.xl),
                  Center(
                    child: Text(
                      GStrings.profileVersion,
                      style: GText.muted.copyWith(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
