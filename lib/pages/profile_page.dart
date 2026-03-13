// ==========================================
// FILE: ./pages/profile_page.dart
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../core/timezone.dart';
import '../services/local_db.dart';
import '../services/notification_service.dart';
import '../services/providers.dart';

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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: GColors.danger,
          content: Text(
            GStrings.profileHabitErrSnack,
            style: GText.body,
          ),
        ),
      );
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: GColors.danger,
          content: Text(
            GStrings.profileSignOutErr,
            style: GText.body,
          ),
        ),
      );
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
              title: Text(GStrings.profileSignOutTitle, style: GText.subheading),
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

  String _safeText(String? value, {String fallback = '—'}) {
    final clean = value?.trim() ?? '';
    return clean.isEmpty ? fallback : clean;
  }

  String _buildInitials(String displayName) {
    final clean = displayName.trim();
    if (clean.isEmpty || clean == '—') return 'GN';

    final parts = clean
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'GN';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    final displayName = _safeText(user?.displayName);
    final email = _safeText(user?.email);
    final timezone = _safeText(
      user?.timezone,
      fallback: deviceTimezone(),
    );
    final initials = _buildInitials(displayName);
    final themeMode = ref.watch(themeModeProvider);
    final themeLabel = switch (themeMode) {
      ThemeMode.light => GStrings.profileThemeLight,
      ThemeMode.dark => GStrings.profileThemeDark,
      ThemeMode.system => GStrings.profileThemeSystem,
    };

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
                    initials: initials,
                    displayName: displayName,
                    email: email,
                  ),
                  const SizedBox(height: GSpacing.xl),
                  const _SectionTitle(GStrings.profileSecAccount),
                  const SizedBox(height: GSpacing.sm),
                  _CardSection(
                    children: [
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: GStrings.profileDisplayName,
                        value: displayName,
                      ),
                      const _SectionDivider(),
                      _InfoRow(
                        icon: Icons.alternate_email_rounded,
                        label: GStrings.profileEmail,
                        value: email,
                      ),
                      const _SectionDivider(),
                      _InfoRow(
                        icon: Icons.public_outlined,
                        label: GStrings.profileTimezone,
                        value: timezone,
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
                        value: themeLabel,
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GSpacing.sm,
        GSpacing.sm,
        GSpacing.pagePadding,
        GSpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: GColors.textPrimary,
            ),
          ),
          const SizedBox(width: GSpacing.xs),
          Expanded(
            child: Text(
              GStrings.profileHeader,
              style: GText.heading.copyWith(
                fontSize: 28,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.initials,
    required this.displayName,
    required this.email,
  });

  final String initials;
  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GSpacing.lg),
      decoration: BoxDecoration(
        color: GColors.surface,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        border: Border.all(color: GColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: GColors.orange,
            child: Text(
              initials,
              style: GText.heading.copyWith(
                fontSize: 22,
                height: 1.0,
                color: GColors.background,
              ),
            ),
          ),
          const SizedBox(width: GSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GText.subheading.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GText.muted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GText.label.copyWith(
        fontSize: 12,
        color: GColors.textMuted,
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GColors.surface,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        border: Border.all(color: GColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GSpacing.md,
        vertical: GSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: GColors.textMuted),
          const SizedBox(width: GSpacing.md),
          Expanded(
            child: Text(label, style: GText.muted),
          ),
          const SizedBox(width: GSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GText.subheading.copyWith(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GSpacing.md,
            vertical: GSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: GSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: GText.subheading.copyWith(fontSize: 15),
                ),
              ),
              const SizedBox(width: GSpacing.md),
              Text(
                value,
                style: GText.subheading.copyWith(
                  fontSize: 15,
                  color: accent,
                ),
              ),
              const SizedBox(width: GSpacing.xs),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({
    required this.icon,
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GSpacing.md,
            vertical: GSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: GColors.danger),
              const SizedBox(width: GSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: GText.subheading.copyWith(
                    fontSize: 15,
                    color: GColors.danger,
                  ),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: GColors.danger,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: GColors.danger,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: GColors.border,
    );
  }
}
